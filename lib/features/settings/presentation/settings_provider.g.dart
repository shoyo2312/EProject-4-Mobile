// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsRepositoryHash() =>
    r'f6c83af3cfad335c638bf83039f3d5a971d55add';

/// See also [settingsRepository].
@ProviderFor(settingsRepository)
final settingsRepositoryProvider = Provider<SettingsRepository>.internal(
  settingsRepository,
  name: r'settingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsRepositoryRef = ProviderRef<SettingsRepository>;
String _$screenTimeWeekHash() => r'fd7dc8f115050edbc4051f7f8d23eae62e05d963';

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

/// One week of the summary chart. [weekStart] is a Monday, "YYYY-MM-DD".
///
/// Copied from [screenTimeWeek].
@ProviderFor(screenTimeWeek)
const screenTimeWeekProvider = ScreenTimeWeekFamily();

/// One week of the summary chart. [weekStart] is a Monday, "YYYY-MM-DD".
///
/// Copied from [screenTimeWeek].
class ScreenTimeWeekFamily extends Family<AsyncValue<ScreenTimeWeek>> {
  /// One week of the summary chart. [weekStart] is a Monday, "YYYY-MM-DD".
  ///
  /// Copied from [screenTimeWeek].
  const ScreenTimeWeekFamily();

  /// One week of the summary chart. [weekStart] is a Monday, "YYYY-MM-DD".
  ///
  /// Copied from [screenTimeWeek].
  ScreenTimeWeekProvider call(String weekStart) {
    return ScreenTimeWeekProvider(weekStart);
  }

  @override
  ScreenTimeWeekProvider getProviderOverride(
    covariant ScreenTimeWeekProvider provider,
  ) {
    return call(provider.weekStart);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'screenTimeWeekProvider';
}

/// One week of the summary chart. [weekStart] is a Monday, "YYYY-MM-DD".
///
/// Copied from [screenTimeWeek].
class ScreenTimeWeekProvider extends AutoDisposeFutureProvider<ScreenTimeWeek> {
  /// One week of the summary chart. [weekStart] is a Monday, "YYYY-MM-DD".
  ///
  /// Copied from [screenTimeWeek].
  ScreenTimeWeekProvider(String weekStart)
    : this._internal(
        (ref) => screenTimeWeek(ref as ScreenTimeWeekRef, weekStart),
        from: screenTimeWeekProvider,
        name: r'screenTimeWeekProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$screenTimeWeekHash,
        dependencies: ScreenTimeWeekFamily._dependencies,
        allTransitiveDependencies:
            ScreenTimeWeekFamily._allTransitiveDependencies,
        weekStart: weekStart,
      );

  ScreenTimeWeekProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.weekStart,
  }) : super.internal();

  final String weekStart;

  @override
  Override overrideWith(
    FutureOr<ScreenTimeWeek> Function(ScreenTimeWeekRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScreenTimeWeekProvider._internal(
        (ref) => create(ref as ScreenTimeWeekRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        weekStart: weekStart,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ScreenTimeWeek> createElement() {
    return _ScreenTimeWeekProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScreenTimeWeekProvider && other.weekStart == weekStart;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, weekStart.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScreenTimeWeekRef on AutoDisposeFutureProviderRef<ScreenTimeWeek> {
  /// The parameter `weekStart` of this provider.
  String get weekStart;
}

class _ScreenTimeWeekProviderElement
    extends AutoDisposeFutureProviderElement<ScreenTimeWeek>
    with ScreenTimeWeekRef {
  _ScreenTimeWeekProviderElement(super.provider);

  @override
  String get weekStart => (origin as ScreenTimeWeekProvider).weekStart;
}

String _$screenTimeLocalStoreHash() =>
    r'6e6fdcd20cf80ce1b1b0465c454a7e113969a58c';

/// See also [screenTimeLocalStore].
@ProviderFor(screenTimeLocalStore)
final screenTimeLocalStoreProvider =
    FutureProvider<ScreenTimeLocalStore>.internal(
      screenTimeLocalStore,
      name: r'screenTimeLocalStoreProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$screenTimeLocalStoreHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScreenTimeLocalStoreRef = FutureProviderRef<ScreenTimeLocalStore>;
String _$accountSettingsHash() => r'4b82b4109507c78e3c5f7a99ef89bd0480d48ec7';

/// One shared copy of `GET /me/settings` for the signed-in account — the
/// Settings screen and the screen-time guard read the same one. Null when
/// signed out.
///
/// Copied from [AccountSettings].
@ProviderFor(AccountSettings)
final accountSettingsProvider =
    AsyncNotifierProvider<AccountSettings, UserSettings?>.internal(
      AccountSettings.new,
      name: r'accountSettingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$accountSettingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AccountSettings = AsyncNotifier<UserSettings?>;
String _$keywordFiltersHash() => r'db578b4552a18d627b3c8ce53b7f977ac4ffeaf7';

/// Filter keywords, newest first.
///
/// Copied from [KeywordFilters].
@ProviderFor(KeywordFilters)
final keywordFiltersProvider =
    AutoDisposeAsyncNotifierProvider<
      KeywordFilters,
      List<KeywordFilter>
    >.internal(
      KeywordFilters.new,
      name: r'keywordFiltersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$keywordFiltersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$KeywordFilters = AutoDisposeAsyncNotifier<List<KeywordFilter>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

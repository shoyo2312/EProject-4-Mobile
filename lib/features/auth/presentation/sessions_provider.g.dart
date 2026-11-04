// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionsHash() => r'2b5251b5a812aa5f3596b662c01f542c58ef925b';

/// The devices signed in to this account, for the "Devices" screen.
///
/// Copied from [Sessions].
@ProviderFor(Sessions)
final sessionsProvider =
    AutoDisposeAsyncNotifierProvider<Sessions, List<SessionModel>>.internal(
      Sessions.new,
      name: r'sessionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Sessions = AutoDisposeAsyncNotifier<List<SessionModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

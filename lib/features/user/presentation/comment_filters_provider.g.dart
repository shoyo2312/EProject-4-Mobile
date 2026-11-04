// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_filters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentFiltersHash() => r'788e6d14f52c61b36a2cd11cc74b3dd31645a08b';

/// The signed-in account's comment filters (user doc 3.14–3.15).
///
/// Copied from [CommentFilters].
@ProviderFor(CommentFilters)
final commentFiltersProvider =
    AutoDisposeAsyncNotifierProvider<
      CommentFilters,
      CommentFilterSettings
    >.internal(
      CommentFilters.new,
      name: r'commentFiltersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$commentFiltersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CommentFilters = AutoDisposeAsyncNotifier<CommentFilterSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

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
String _$commentNotifierHash() => r'd1b4b0e9970b27acfa342f6a7fe94c98eaee5758';

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

/// See also [CommentNotifier].
@ProviderFor(CommentNotifier)
const commentNotifierProvider = CommentNotifierFamily();

/// See also [CommentNotifier].
class CommentNotifierFamily extends Family<AsyncValue<List<CommentModel>>> {
  /// See also [CommentNotifier].
  const CommentNotifierFamily();

  /// See also [CommentNotifier].
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

/// See also [CommentNotifier].
class CommentNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          CommentNotifier,
          List<CommentModel>
        > {
  /// See also [CommentNotifier].
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

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

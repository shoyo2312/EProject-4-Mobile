// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$uploadNotifierHash() => r'12faf3bf8c5246297786454015940928a21066a9';

/// Kept alive: an upload has to survive the user switching tabs while the
/// bytes are going up — a dropped notifier would cancel the request mid-file.
///
/// Copied from [UploadNotifier].
@ProviderFor(UploadNotifier)
final uploadNotifierProvider =
    NotifierProvider<UploadNotifier, UploadState>.internal(
      UploadNotifier.new,
      name: r'uploadNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$uploadNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UploadNotifier = Notifier<UploadState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

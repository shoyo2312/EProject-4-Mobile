// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationRepositoryHash() =>
    r'1427b50f3d8b9a267d7276d9a5e1181fff000c92';

/// See also [notificationRepository].
@ProviderFor(notificationRepository)
final notificationRepositoryProvider =
    Provider<NotificationRepository>.internal(
      notificationRepository,
      name: r'notificationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationRepositoryRef = ProviderRef<NotificationRepository>;
String _$inboxHash() => r'0c49b7c319fe2adebe0b241ebeaafc364a83f84d';

/// The caller's inbox, newest first.
///
/// Signed out there is nothing to read — the endpoint would 401 — so a guest
/// gets an empty list rather than an error page behind the Inbox tab.
///
/// Copied from [Inbox].
@ProviderFor(Inbox)
final inboxProvider =
    AutoDisposeAsyncNotifierProvider<Inbox, List<NotificationModel>>.internal(
      Inbox.new,
      name: r'inboxProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$inboxHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Inbox = AutoDisposeAsyncNotifier<List<NotificationModel>>;
String _$unreadCountHash() => r'22ad6eb51d7cf7c8ce7cb3a00b129a32085a4636';

/// The nav bar badge. Its own request on purpose: the Inbox tab is not built
/// until it is opened, so reading the count off [Inbox] would mean pulling the
/// whole inbox down to draw a number.
///
/// Copied from [UnreadCount].
@ProviderFor(UnreadCount)
final unreadCountProvider =
    AutoDisposeAsyncNotifierProvider<UnreadCount, int>.internal(
      UnreadCount.new,
      name: r'unreadCountProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$unreadCountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UnreadCount = AutoDisposeAsyncNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

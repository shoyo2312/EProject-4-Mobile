// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatSocketHash() => r'0000000000000000000000000000000000000001';

/// The one chat socket. Opens on the first live stream and closes with the
/// last, so a signed-out app holds nothing open.
///
/// Copied from [chatSocket].
@ProviderFor(chatSocket)
final chatSocketProvider = Provider<ChatSocket>.internal(
  chatSocket,
  name: r'chatSocketProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatSocketHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatSocketRef = ProviderRef<ChatSocket>;
String _$chatRepositoryHash() => r'304f2db6d633d3fcccd0e133797cc02e8ceeddca';

/// See also [chatRepository].
@ProviderFor(chatRepository)
final chatRepositoryProvider = Provider<ChatRepository>.internal(
  chatRepository,
  name: r'chatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatRepositoryRef = ProviderRef<ChatRepository>;
String _$conversationsHash() => r'53f585c9cb7de703f7994d126b7656ba4962a123';

/// The thread list, most recently active first, kept current over the socket.
///
/// Signed out there is nothing to list — every endpoint here needs a token —
/// so a guest gets an empty list rather than a 401 behind the screen.
///
/// Copied from [Conversations].
@ProviderFor(Conversations)
final conversationsProvider =
    AutoDisposeAsyncNotifierProvider<
      Conversations,
      List<ConversationModel>
    >.internal(
      Conversations.new,
      name: r'conversationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Conversations = AutoDisposeAsyncNotifier<List<ConversationModel>>;
String _$unreadConversationsHash() =>
    r'0000000000000000000000000000000000000002';

/// Threads with something the user has not read — the dot on the Inbox tab
/// and its Messages shortcut. Watching it keeps the conversation list, and so
/// the inbox socket, alive while the app is up.
///
/// Copied from [unreadConversations].
@ProviderFor(unreadConversations)
final unreadConversationsProvider = AutoDisposeProvider<int>.internal(
  unreadConversations,
  name: r'unreadConversationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadConversationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadConversationsRef = AutoDisposeProviderRef<int>;
String _$threadHash() => r'd06afd6adf44045ae1e5c9834d0c6e0e4a8ced4a';

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

abstract class _$Thread
    extends BuildlessAutoDisposeAsyncNotifier<List<MessageModel>> {
  late final String conversationId;

  FutureOr<List<MessageModel>> build(String conversationId);
}

/// One thread: a page of history, plus everything that arrives while it is on
/// screen.
///
/// Newest first, which is the order the server sorts in and the order the view
/// renders (a reversed list, so index 0 sits at the bottom).
///
/// Copied from [Thread].
@ProviderFor(Thread)
const threadProvider = ThreadFamily();

/// One thread: a page of history, plus everything that arrives while it is on
/// screen.
///
/// Newest first, which is the order the server sorts in and the order the view
/// renders (a reversed list, so index 0 sits at the bottom).
///
/// Copied from [Thread].
class ThreadFamily extends Family<AsyncValue<List<MessageModel>>> {
  /// One thread: a page of history, plus everything that arrives while it is on
  /// screen.
  ///
  /// Newest first, which is the order the server sorts in and the order the view
  /// renders (a reversed list, so index 0 sits at the bottom).
  ///
  /// Copied from [Thread].
  const ThreadFamily();

  /// One thread: a page of history, plus everything that arrives while it is on
  /// screen.
  ///
  /// Newest first, which is the order the server sorts in and the order the view
  /// renders (a reversed list, so index 0 sits at the bottom).
  ///
  /// Copied from [Thread].
  ThreadProvider call(String conversationId) {
    return ThreadProvider(conversationId);
  }

  @override
  ThreadProvider getProviderOverride(covariant ThreadProvider provider) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'threadProvider';
}

/// One thread: a page of history, plus everything that arrives while it is on
/// screen.
///
/// Newest first, which is the order the server sorts in and the order the view
/// renders (a reversed list, so index 0 sits at the bottom).
///
/// Copied from [Thread].
class ThreadProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Thread, List<MessageModel>> {
  /// One thread: a page of history, plus everything that arrives while it is on
  /// screen.
  ///
  /// Newest first, which is the order the server sorts in and the order the view
  /// renders (a reversed list, so index 0 sits at the bottom).
  ///
  /// Copied from [Thread].
  ThreadProvider(String conversationId)
    : this._internal(
        () => Thread()..conversationId = conversationId,
        from: threadProvider,
        name: r'threadProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$threadHash,
        dependencies: ThreadFamily._dependencies,
        allTransitiveDependencies: ThreadFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ThreadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  FutureOr<List<MessageModel>> runNotifierBuild(covariant Thread notifier) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(Thread Function() create) {
    return ProviderOverride(
      origin: this,
      override: ThreadProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Thread, List<MessageModel>>
  createElement() {
    return _ThreadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ThreadProvider && other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ThreadRef on AutoDisposeAsyncNotifierProviderRef<List<MessageModel>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ThreadProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Thread, List<MessageModel>>
    with ThreadRef {
  _ThreadProviderElement(super.provider);

  @override
  String get conversationId => (origin as ThreadProvider).conversationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

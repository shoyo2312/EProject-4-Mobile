// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatSocketHash() => r'd24db1e25799ccd303c8013727cd92c4e8887822';

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
String _$chatRepositoryHash() => r'd38eb0620dbbe938f2cd05b06b16c71613bd8dc7';

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
String _$stickerPacksHash() => r'33071afeed94a5059c937c986dc1dead4611a2e5';

/// The sticker catalog, fetched once per session — it changes with a server
/// release, not while the app is open.
///
/// Copied from [stickerPacks].
@ProviderFor(stickerPacks)
final stickerPacksProvider = FutureProvider<List<StickerPack>>.internal(
  stickerPacks,
  name: r'stickerPacksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stickerPacksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StickerPacksRef = FutureProviderRef<List<StickerPack>>;
String _$chatImageBytesHash() => r'45218dafe05594ce9aa7c34894c175d4f0f7b535';

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

/// A chat picture's bytes, fetched with the viewer's token.
///
/// Copied from [chatImageBytes].
@ProviderFor(chatImageBytes)
const chatImageBytesProvider = ChatImageBytesFamily();

/// A chat picture's bytes, fetched with the viewer's token.
///
/// Copied from [chatImageBytes].
class ChatImageBytesFamily extends Family<AsyncValue<Uint8List>> {
  /// A chat picture's bytes, fetched with the viewer's token.
  ///
  /// Copied from [chatImageBytes].
  const ChatImageBytesFamily();

  /// A chat picture's bytes, fetched with the viewer's token.
  ///
  /// Copied from [chatImageBytes].
  ChatImageBytesProvider call(ChatImageModel image) {
    return ChatImageBytesProvider(image);
  }

  @override
  ChatImageBytesProvider getProviderOverride(
    covariant ChatImageBytesProvider provider,
  ) {
    return call(provider.image);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatImageBytesProvider';
}

/// A chat picture's bytes, fetched with the viewer's token.
///
/// Copied from [chatImageBytes].
class ChatImageBytesProvider extends AutoDisposeFutureProvider<Uint8List> {
  /// A chat picture's bytes, fetched with the viewer's token.
  ///
  /// Copied from [chatImageBytes].
  ChatImageBytesProvider(ChatImageModel image)
    : this._internal(
        (ref) => chatImageBytes(ref as ChatImageBytesRef, image),
        from: chatImageBytesProvider,
        name: r'chatImageBytesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatImageBytesHash,
        dependencies: ChatImageBytesFamily._dependencies,
        allTransitiveDependencies:
            ChatImageBytesFamily._allTransitiveDependencies,
        image: image,
      );

  ChatImageBytesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.image,
  }) : super.internal();

  final ChatImageModel image;

  @override
  Override overrideWith(
    FutureOr<Uint8List> Function(ChatImageBytesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatImageBytesProvider._internal(
        (ref) => create(ref as ChatImageBytesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        image: image,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Uint8List> createElement() {
    return _ChatImageBytesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatImageBytesProvider && other.image == image;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, image.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatImageBytesRef on AutoDisposeFutureProviderRef<Uint8List> {
  /// The parameter `image` of this provider.
  ChatImageModel get image;
}

class _ChatImageBytesProviderElement
    extends AutoDisposeFutureProviderElement<Uint8List>
    with ChatImageBytesRef {
  _ChatImageBytesProviderElement(super.provider);

  @override
  ChatImageModel get image => (origin as ChatImageBytesProvider).image;
}

String _$unreadConversationsHash() =>
    r'2ef08a559f3ff7999b0d076da857cf58150c4d31';

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
String _$conversationsHash() => r'2ef1726678c07f144aba5a650a388f0667539b46';

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
String _$threadHash() => r'f93fbd60a7157c8411058e887fdc6e7f4b4fcb1e';

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

String _$outgoingImagesHash() => r'1f5766724ce6a39ba7c7746e15ca10522a78aa3e';

abstract class _$OutgoingImages
    extends BuildlessAutoDisposeNotifier<List<OutgoingImage>> {
  late final String conversationId;

  List<OutgoingImage> build(String conversationId);
}

/// Pictures being sent into one thread, oldest first. Kept alive while one is
/// in flight, so leaving the thread does not cancel it.
///
/// Copied from [OutgoingImages].
@ProviderFor(OutgoingImages)
const outgoingImagesProvider = OutgoingImagesFamily();

/// Pictures being sent into one thread, oldest first. Kept alive while one is
/// in flight, so leaving the thread does not cancel it.
///
/// Copied from [OutgoingImages].
class OutgoingImagesFamily extends Family<List<OutgoingImage>> {
  /// Pictures being sent into one thread, oldest first. Kept alive while one is
  /// in flight, so leaving the thread does not cancel it.
  ///
  /// Copied from [OutgoingImages].
  const OutgoingImagesFamily();

  /// Pictures being sent into one thread, oldest first. Kept alive while one is
  /// in flight, so leaving the thread does not cancel it.
  ///
  /// Copied from [OutgoingImages].
  OutgoingImagesProvider call(String conversationId) {
    return OutgoingImagesProvider(conversationId);
  }

  @override
  OutgoingImagesProvider getProviderOverride(
    covariant OutgoingImagesProvider provider,
  ) {
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
  String? get name => r'outgoingImagesProvider';
}

/// Pictures being sent into one thread, oldest first. Kept alive while one is
/// in flight, so leaving the thread does not cancel it.
///
/// Copied from [OutgoingImages].
class OutgoingImagesProvider
    extends
        AutoDisposeNotifierProviderImpl<OutgoingImages, List<OutgoingImage>> {
  /// Pictures being sent into one thread, oldest first. Kept alive while one is
  /// in flight, so leaving the thread does not cancel it.
  ///
  /// Copied from [OutgoingImages].
  OutgoingImagesProvider(String conversationId)
    : this._internal(
        () => OutgoingImages()..conversationId = conversationId,
        from: outgoingImagesProvider,
        name: r'outgoingImagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$outgoingImagesHash,
        dependencies: OutgoingImagesFamily._dependencies,
        allTransitiveDependencies:
            OutgoingImagesFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  OutgoingImagesProvider._internal(
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
  List<OutgoingImage> runNotifierBuild(covariant OutgoingImages notifier) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(OutgoingImages Function() create) {
    return ProviderOverride(
      origin: this,
      override: OutgoingImagesProvider._internal(
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
  AutoDisposeNotifierProviderElement<OutgoingImages, List<OutgoingImage>>
  createElement() {
    return _OutgoingImagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OutgoingImagesProvider &&
        other.conversationId == conversationId;
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
mixin OutgoingImagesRef on AutoDisposeNotifierProviderRef<List<OutgoingImage>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _OutgoingImagesProviderElement
    extends
        AutoDisposeNotifierProviderElement<OutgoingImages, List<OutgoingImage>>
    with OutgoingImagesRef {
  _OutgoingImagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as OutgoingImagesProvider).conversationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
